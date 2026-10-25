import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/dive_star_application.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/features/admin/analytics/admin_option_groups.dart';
import 'package:dive_travel_app/features/admin/analytics/admin_report_math.dart';
import 'package:dive_travel_app/features/admin/analytics/admin_sales_math.dart';
import 'package:dive_travel_app/features/admin/analytics/admin_stats_math.dart';

void main() {
  final now = DateTime(2026, 10, 21, 12);
  final window = adminStatsWindow(preset: AdminStatsPreset.thisMonth, now: now);

  TourBooking booking({
    required String id,
    required String optionName,
    String productId = 'p1',
    String optionId = '',
    DateTime? createdAt,
  }) {
    return TourBooking(
      id: id,
      shopId: 'shop-a',
      shopName: '제주',
      productId: productId,
      productName: '펀다이빙',
      optionId: optionId,
      optionName: optionName,
      price: 10000,
      createdAt: createdAt ?? DateTime(2026, 10, 4),
      paymentStatus: PaymentStatus.captured,
      status: BookingStatus.confirmed,
    );
  }

  const catalog = [
    AdminListedOption(
      shopId: 'shop-a',
      productId: 'p1',
      optionId: 'gear',
      name: '렌탈',
      group: 'gear',
    ),
    AdminListedOption(
      shopId: 'shop-a',
      productId: 'p1',
      optionId: 'ride',
      name: '공항픽업',
      group: 'transfer',
    ),
    AdminListedOption(
      shopId: 'shop-a',
      productId: 'p1',
      optionId: 'old',
      name: '기념품',
      group: '',
    ),
  ];

  int nameTotal(AdminOptionGroupTally tally) {
    return tally.names.fold<int>(0, (sum, row) => sum + row.count);
  }

  test('그룹 없는 옛 상품과 찾을 수 없는 옵션은 미분류이고 합은 같다', () {
    final tally = countAdminOptionGroups(
      bookings: [
        booking(id: 'old', optionName: '기념품'),
        booking(id: 'gone', optionName: '사라진옵션', productId: 'missing'),
        booking(id: 'out', optionName: '렌탈', createdAt: DateTime(2026, 9, 1)),
      ],
      window: window,
      catalog: catalog,
    );
    expect(tally.lines.map((line) => line.group), ['', '']);
    expect(tally.hasKnownGroup, isFalse);
    expect(tally.total, nameTotal(tally));
    expect(tally.total, 2);
  });

  test('그룹이 있으면 그 칸에만 세고 그룹 합은 옵션 전체 합과 같다', () {
    final tally = countAdminOptionGroups(
      bookings: [
        booking(id: 'both', optionName: '렌탈 · 공항픽업', optionId: 'gear'),
        booking(id: 'dup', optionName: '렌탈', optionId: 'missing-id'),
      ],
      window: window,
      catalog: catalog,
    );
    expect(tally.lines.where((line) => line.group == 'gear').single.count, 2);
    expect(
      tally.lines.where((line) => line.group == 'transfer').single.count,
      1,
    );
    expect(tally.lines.where((line) => line.group.isEmpty), isEmpty);
    expect(tally.hasKnownGroup, isTrue);
    expect(tally.total, nameTotal(tally));
    expect(tally.total, 3);
  });

  test('같은 이름이 두 옵션이면 예약 옵션 id가 그룹을 정한다', () {
    final tally = countAdminOptionGroups(
      bookings: [
        booking(id: 'a', optionName: '렌탈', optionId: 'photo'),
      ],
      window: window,
      catalog: const [
        AdminListedOption(
          shopId: 'shop-a',
          productId: 'p1',
          optionId: 'photo',
          name: '렌탈',
          group: 'media',
        ),
        AdminListedOption(
          shopId: 'shop-a',
          productId: 'p1',
          optionId: 'tank',
          name: '렌탈',
          group: 'gear',
        ),
      ],
    );
    expect(tally.lines.single.group, 'media');
    expect(tally.total, 1);
  });

  test('통계와 보고서는 같은 그룹 합을 쓴다', () {
    final bookings = [
      booking(id: 'both', optionName: '렌탈 · 공항픽업', optionId: 'gear'),
    ];
    final snap = buildAdminStatsSnapshot(
      bookings: bookings,
      window: window,
      now: now,
      catalog: const [],
      members: const <MemberAccount>[],
      shops: const [],
      applications: const <DiveStarApplication>[],
      optionCatalog: catalog,
    );
    final report = buildAdminReportDocument(
      bookings: bookings,
      window: window,
      compareWindow: adminReportCompareWindow(
        window: window,
        compare: AdminReportCompare.none,
      ),
      catalog: const [],
      buckets: AdminSalesBucket.values.toSet(),
      shopIds: const {},
      productKeys: const {'shop-a|p1'},
      periodLabel: '10월',
      showSummary: true,
      showTrend: true,
      showPartners: true,
      showProducts: true,
      showOptions: true,
      showCancels: true,
      showBasis: true,
      basisText: '',
      fontLicense: '',
      optionCatalog: catalog,
    );
    expect(snap.optionGroupsKnown, isTrue);
    expect(report.optionGroupsKnown, isTrue);
    expect(snap.optionGroups.fold<int>(0, (sum, line) => sum + line.count), 2);
    expect(report.optionGroups.fold<int>(0, (sum, line) => sum + line.count), 2);
    expect(
      report.options.fold<int>(0, (sum, row) => sum + row.count),
      2,
    );
  });
}
