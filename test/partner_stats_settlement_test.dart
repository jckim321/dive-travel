import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_settlement_logic.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_stats_logic.dart';

TourBooking _b({
  required String id,
  required DateTime createdAt,
  required int price,
  BookingStatus status = BookingStatus.confirmed,
  PaymentStatus payment = PaymentStatus.captured,
  int refundAmount = 0,
  String productName = 'Pkg',
  String productId = 'p1',
  int partySize = 2,
}) {
  return TourBooking(
    id: id,
    shopId: 'shop',
    shopName: 'Shop',
    productName: productName,
    productId: productId,
    price: price,
    createdAt: createdAt,
    status: status,
    paymentStatus: payment,
    refundAmount: refundAmount,
    partySize: partySize,
  );
}

void main() {
  group('partner settlement', () {
    test('gross includes later cancels; net = gross - refunds; counts split',
        () {
      // Jan receive: A kept, B full refund, C partial refund (cancel in Feb).
      final jan = DateTime(2026, 1, 10);
      final feb = DateTime(2026, 2, 5);
      final bookings = [
        _b(id: 'a', createdAt: jan, price: 100000),
        _b(
          id: 'b',
          createdAt: jan.add(const Duration(days: 1)),
          price: 200000,
          status: BookingStatus.cancelled,
          payment: PaymentStatus.refunded,
          refundAmount: 200000,
        ),
        _b(
          id: 'c',
          createdAt: jan.add(const Duration(days: 2)),
          price: 300000,
          status: BookingStatus.cancelled,
          payment: PaymentStatus.refunded,
          refundAmount: 150000, // partial (penalty kept)
        ),
        // Received in Feb (active) — must not inflate Jan.
        _b(
          id: 'd-noise',
          createdAt: feb,
          price: 50000,
          status: BookingStatus.confirmed,
        ),
        // Weather cancel received in Jan; cancel "happens" later — still Jan.
        _b(
          id: 'e-weather',
          createdAt: jan.add(const Duration(days: 3)),
          price: 80000,
          status: BookingStatus.weatherCancelled,
          payment: PaymentStatus.refunded,
          refundAmount: 80000,
        ),
      ];

      final janSum = computePartnerSettlementMonth(
        bookings: bookings,
        year: 2026,
        month: 1,
      );
      // 3 paid + 1 weather: gross includes all; refunds for 3 cancels.
      expect(janSum.grossPaid, 100000 + 200000 + 300000 + 80000);
      expect(janSum.refundTotal, 200000 + 150000 + 80000);
      expect(janSum.netSales, 100000 + 150000); // kept + partial penalty
      expect(janSum.validCount, 1);
      expect(janSum.cancelledCount, 3);
      expect(janSum.rows, hasLength(4));

      final febSum = computePartnerSettlementMonth(
        bookings: bookings,
        year: 2026,
        month: 2,
      );
      expect(febSum.grossPaid, 50000);
      expect(febSum.refundTotal, 0);
      expect(febSum.validCount, 1);
      expect(febSum.cancelledCount, 0);
    });

    test('receive month and cancel month differ — stays in receive month', () {
      final receive = DateTime(2026, 1, 28);
      final bookings = [
        _b(
          id: 'cross',
          createdAt: receive,
          price: 400000,
          status: BookingStatus.cancelled,
          payment: PaymentStatus.refunded,
          refundAmount: 200000,
        ),
      ];
      final jan = computePartnerSettlementMonth(
        bookings: bookings,
        year: 2026,
        month: 1,
      );
      expect(jan.grossPaid, 400000);
      expect(jan.refundTotal, 200000);
      expect(jan.netSales, 200000);
      expect(jan.cancelledCount, 1);

      final feb = computePartnerSettlementMonth(
        bookings: bookings,
        year: 2026,
        month: 2,
      );
      expect(feb.grossPaid, 0);
      expect(feb.refundTotal, 0);
      expect(feb.rows, isEmpty);
    });

    test('empty month is zeros', () {
      final sum = computePartnerSettlementMonth(
        bookings: const [],
        year: 2026,
        month: 3,
      );
      expect(sum.grossPaid, 0);
      expect(sum.refundTotal, 0);
      expect(sum.netSales, 0);
      expect(sum.validCount, 0);
      expect(sum.cancelledCount, 0);
    });
  });

  group('partner product stats', () {
    test('groups paid active by product; excludes cancelled and out of range',
        () {
      final now = DateTime(2026, 3, 15);
      final bookings = [
        _b(
          id: '1',
          createdAt: DateTime(2026, 3, 10),
          price: 1,
          productId: 'bohol',
          productName: '보홀 패키지',
          partySize: 2,
        ),
        _b(
          id: '2',
          createdAt: DateTime(2026, 3, 12),
          price: 1,
          productId: 'bohol',
          productName: '보홀 패키지',
          partySize: 1,
        ),
        _b(
          id: '3',
          createdAt: DateTime(2026, 3, 11),
          price: 1,
          productId: 'night',
          productName: '나이트',
          partySize: 3,
        ),
        _b(
          id: 'x',
          createdAt: DateTime(2026, 3, 10),
          price: 1,
          status: BookingStatus.cancelled,
          payment: PaymentStatus.refunded,
          refundAmount: 1,
          productId: 'bohol',
        ),
        _b(
          id: 'old',
          createdAt: DateTime(2026, 1, 1),
          price: 1,
          productId: 'bohol',
        ),
      ];

      final rows = computeProductBookingRows(
        bookings: bookings,
        period: PartnerStatsPeriod.thisMonth,
        now: now,
      );
      expect(rows, hasLength(2));
      final bohol = rows.firstWhere((r) => r.productKey == 'bohol');
      expect(bohol.bookingCount, 2);
      expect(bohol.guestCount, 3);
      final night = rows.firstWhere((r) => r.productKey == 'night');
      expect(night.bookingCount, 1);
      expect(night.guestCount, 3);
    });
  });
}
