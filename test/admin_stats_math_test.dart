import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/features/admin/analytics/admin_sales_math.dart';
import 'package:dive_travel_app/features/admin/analytics/admin_stats_math.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_dive_star_milestone.dart';

void main() {
  final now = DateTime(2026, 10, 21, 12);

  TourBooking booking({
    required String id,
    required DateTime createdAt,
    int price = 10000,
    PaymentStatus paymentStatus = PaymentStatus.captured,
    BookingStatus status = BookingStatus.confirmed,
    int refundAmount = 0,
    String uid = 'u1',
    String optionName = '',
    DateTime? tourDate,
    String productName = '펀다이빙',
  }) {
    return TourBooking(
      id: id,
      uid: uid,
      shopId: 'shop-a',
      shopName: '제주 오렌지',
      productName: productName,
      price: price,
      createdAt: createdAt,
      paymentStatus: paymentStatus,
      status: status,
      refundAmount: refundAmount,
      optionName: optionName,
      tourDate: tourDate,
    );
  }

  test('통계 일별 합은 그 달 판매 순매출과 같다', () {
    final bookings = [
      booking(
        id: 'a',
        createdAt: DateTime(2026, 10, 2, 9),
        price: 100000,
        paymentStatus: PaymentStatus.refunded,
        status: BookingStatus.cancelled,
        refundAmount: 25000,
        optionName: '장비 · 픽업',
        tourDate: DateTime(2026, 10, 9),
      ),
      booking(
        id: 'b',
        createdAt: DateTime(2026, 10, 3, 9),
        price: 40000,
        uid: 'u2',
      ),
    ];
    final window = adminStatsWindow(preset: AdminStatsPreset.thisMonth, now: now);
    final snap = buildAdminStatsSnapshot(
      bookings: bookings,
      window: window,
      now: now,
      catalog: const [],
      members: [
        MemberAccount(
          uid: 'u1',
          email: 'a@b.c',
          displayName: '김',
          grade: MemberGrade.gold,
          paidPurchaseCount: 3,
        ),
        MemberAccount(
          uid: 'u2',
          email: 'c@d.e',
          displayName: '이',
          grade: MemberGrade.silver,
          paidPurchaseCount: 1,
        ),
      ],
      shops: const [
        AdminShopGrade(shopId: 'shop-a', diveStar: 1),
      ],
      applications: const [],
    );
    final dailySum = snap.dailyNet.fold<int>(0, (sum, value) => sum + value);
    expect(dailySum, snap.sales.totals.net);
    expect(snap.sales.totals.net, 115000);
    expect(snap.returnBuyers, 1);
    expect(snap.newBuyers, 1);
    expect(snap.gradeCounts[MemberGrade.gold], 1);
    expect(snap.topOption, '장비');
    expect(snap.options.map((item) => item.name), containsAll(['장비', '픽업']));
    expect(snap.leadCounts[2], 1);
    expect(snap.diveStarCounts[PartnerDiveStarMilestoneStep.oneStar], 1);
    expect(snap.cancelByMonth, hasLength(12));
    expect(snap.seasonCounts, hasLength(12));
  });

  test('옵션 이름이 없으면 선택 비율은 비어 있다', () {
    final window = adminStatsWindow(preset: AdminStatsPreset.thisMonth, now: now);
    final snap = buildAdminStatsSnapshot(
      bookings: const [],
      window: window,
      now: now,
      catalog: const [],
      members: const [],
      shops: const [],
      applications: const [],
    );
    expect(snap.options, isEmpty);
    expect(snap.topOption, isNull);
    expect(snap.sales.totals.net, 0);
  });
}
