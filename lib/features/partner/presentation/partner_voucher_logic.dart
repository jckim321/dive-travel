import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/models/booking_quote.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

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

/// Party line plus 「1인 1실 n」 when the booking stored a count.
String partnerVoucherPartyWithSingleRooms(
  AppLocalizations l10n,
  TourBooking booking,
  String partyText,
) {
  if (booking.singleRooms < 1) {
    return partyText;
  }
  final rooms = l10n.bookingSingleRooms(booking.singleRooms);
  final party = partyText.trim();
  if (party.isEmpty) {
    return rooms;
  }
  return '$party · $rooms';
}

final _partyMoney = NumberFormat('#,###', 'en_US');

String bookingPartyAmountText(int amount) => _partyMoney.format(amount);

/// Label for one stored party-price row. Empty when the kind is unknown.
String bookingPartyLineLabel(AppLocalizations l10n, BookingPartyLine line) {
  final unit = _partyMoney.format(line.unit);
  return switch (line.kind) {
    'diver' => l10n.bookingPartyDiver(line.count, unit),
    'nondiver' => l10n.bookingPartyNondiver(line.count, unit),
    'child' => l10n.bookingPartyChild(line.count, unit),
    'infant' => l10n.bookingPartyInfant(line.count, unit),
    'foc' => l10n.bookingPartyFoc(line.count),
    'single_room' => l10n.bookingPartySingleRoom(line.count, unit),
    _ => '',
  };
}

/// Add-on quote rows once the package line and single-room line are shown
/// from [TourBooking.partyLines]. Empty when there is no stored breakdown.
List<BookingLine> bookingVoucherAddonLines(TourBooking booking) {
  if (booking.partyLines.isEmpty || booking.quoteLines.isEmpty) {
    return const [];
  }
  final hideSingle =
      booking.partyLines.any((line) => line.kind == 'single_room');
  return [
    for (final line in booking.quoteLines.skip(1))
      if (!hideSingle || line.label != '1인 1실 추가') line,
  ];
}
