import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_voucher_logic.dart';

TourBooking _b({
  required String id,
  BookingStatus status = BookingStatus.requested,
  DateTime? tourDate,
  DateTime? createdAt,
  DateTime? partnerAckedAt,
  int divers = 2,
  int nondivers = 0,
}) {
  final created = createdAt ?? DateTime(2026, 10, 20);
  return TourBooking(
    id: id,
    shopId: 'shop-a',
    shopName: 'Shop',
    productName: 'Package',
    price: 100000,
    createdAt: created,
    tourDate: tourDate ?? created,
    status: status,
    divers: divers,
    nondivers: nondivers,
    partnerAckedAt: partnerAckedAt,
  );
}

void main() {
  final now = DateTime(2026, 10, 25);

  test('tabs: arrived / past / cancelled', () {
    final bookings = [
      _b(id: 'a', tourDate: DateTime(2026, 11, 1)),
      _b(id: 'p', tourDate: DateTime(2026, 10, 1)),
      _b(
        id: 'c',
        status: BookingStatus.cancelled,
        tourDate: DateTime(2026, 11, 2),
      ),
      _b(
        id: 'w',
        status: BookingStatus.weatherCancelled,
        tourDate: DateTime(2026, 11, 3),
      ),
      _b(
        id: 'ok',
        status: BookingStatus.confirmed,
        tourDate: DateTime(2026, 12, 1),
      ),
    ];
    expect(
      filterPartnerVouchers(
        bookings: bookings,
        tab: PartnerVoucherTab.arrived,
        now: now,
      ).map((b) => b.id).toSet(),
      {'ok', 'a'},
    );
    expect(
      filterPartnerVouchers(
        bookings: bookings,
        tab: PartnerVoucherTab.past,
        now: now,
      ).single.id,
      'p',
    );
    expect(
      filterPartnerVouchers(
        bookings: bookings,
        tab: PartnerVoucherTab.cancelled,
        now: now,
      ).map((b) => b.id).toSet(),
      {'c', 'w'},
    );
  });

  test('unread arrived count ignores acked and past', () {
    final bookings = [
      _b(id: 'new', tourDate: DateTime(2026, 11, 1)),
      _b(
        id: 'read',
        tourDate: DateTime(2026, 11, 2),
        partnerAckedAt: DateTime(2026, 10, 24),
      ),
      _b(id: 'old', tourDate: DateTime(2026, 9, 1)),
    ];
    expect(partnerVoucherUnreadArrivedCount(bookings, now: now), 1);
  });

  test('status kinds are honest', () {
    expect(
      partnerVoucherStatusKind(_b(id: 'r')),
      PartnerVoucherStatusKind.awaitingConfirm,
    );
    expect(
      partnerVoucherStatusKind(
        _b(id: 'c', status: BookingStatus.confirmed),
      ),
      PartnerVoucherStatusKind.confirmed,
    );
    expect(
      partnerVoucherStatusKind(
        _b(id: 'x', status: BookingStatus.cancelled),
      ),
      PartnerVoucherStatusKind.cancelled,
    );
  });
}
