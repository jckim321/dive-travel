import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/partner_promotion.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/features/admin/overview/admin_overview_metrics.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_overview_pane.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  final now = DateTime(2026, 10, 21, 15);

  TourBooking booking({
    required String id,
    required DateTime createdAt,
    int price = 10000,
    PaymentStatus paymentStatus = PaymentStatus.captured,
    BookingStatus status = BookingStatus.confirmed,
    int refundAmount = 0,
    DateTime? cancelledAt,
    String shopId = 'shop-a',
    String shopName = '제주 오렌지',
  }) {
    return TourBooking(
      id: id,
      shopId: shopId,
      shopName: shopName,
      productName: '펀다이빙',
      price: price,
      createdAt: createdAt,
      paymentStatus: paymentStatus,
      status: status,
      refundAmount: refundAmount,
      cancelledAt: cancelledAt,
    );
  }

  test('접수일 달의 순매출에서 환불을 빼고, 전월·전년과 비교한다', () {
    final figures = buildAdminOverviewFigures(
      now: now,
      bookings: [
        booking(
          id: 'today',
          createdAt: DateTime(2026, 10, 21, 9),
          price: 100000,
          paymentStatus: PaymentStatus.refunded,
          status: BookingStatus.cancelled,
          refundAmount: 40000,
          cancelledAt: DateTime(2026, 10, 21, 11),
        ),
        booking(
          id: 'sep',
          createdAt: DateTime(2026, 9, 30, 12),
          price: 200000,
        ),
        booking(
          id: 'last-year',
          createdAt: DateTime(2025, 10, 10, 12),
          price: 50000,
        ),
      ],
    );

    expect(figures.todayCount, 1);
    expect(figures.todayGross, 100000);
    expect(figures.todayCancelCount, 1);
    expect(figures.todayRefund, 40000);
    expect(figures.monthNet, 60000);
    expect(figures.previousMonthNet, 200000);
    expect(figures.yearAgoMonthNet, 50000);
    expect(figures.hasYearAgoMonth, isTrue);
    expect(figures.hasYearAgoChart, isTrue);
    expect(figures.last30Net, hasLength(30));
    expect(figures.last14Net, hasLength(14));
  });

  test('예약이 없으면 0이고 전년 비교도 없다', () {
    final figures = buildAdminOverviewFigures(now: now, bookings: const []);
    expect(figures.todayCount, 0);
    expect(figures.monthNet, 0);
    expect(figures.previousMonthNet, 0);
    expect(figures.hasYearAgoMonth, isFalse);
    expect(figures.hasYearAgoChart, isFalse);
    expect(evaluateAdminOverviewAlert(now: now, bookings: const []), isNull);
  });

  test('취소 알림은 3건, 2배, 28일 예약 10건을 모두 만족할 때만 뜬다', () {
    List<TourBooking> baseline(int count) => [
      for (var i = 0; i < count; i++)
        booking(id: 'base-$i', createdAt: DateTime(2026, 10, 1, 8)),
    ];
    List<TourBooking> todayCancels(int count) => [
      for (var i = 0; i < count; i++)
        booking(
          id: 'cancel-$i',
          createdAt: DateTime(2026, 10, 21, 8),
          paymentStatus: PaymentStatus.refunded,
          status: BookingStatus.cancelled,
          refundAmount: 10000,
          cancelledAt: DateTime(2026, 10, 21, 10, i),
        ),
    ];

    expect(
      evaluateAdminOverviewAlert(
        now: now,
        bookings: [...baseline(9), ...todayCancels(3)],
      ),
      isNull,
    );
    expect(
      evaluateAdminOverviewAlert(
        now: now,
        bookings: [...baseline(10), ...todayCancels(2)],
      ),
      isNull,
    );

    final spike = evaluateAdminOverviewAlert(
      now: now,
      bookings: [...baseline(10), ...todayCancels(3)],
    );
    expect(spike?.cancelSpike, isTrue);

    final busy = [
      ...baseline(10),
      ...todayCancels(3),
      for (var i = 0; i < 56; i++)
        booking(
          id: 'old-cancel-$i',
          createdAt: DateTime(2026, 10, 3, 8),
          paymentStatus: PaymentStatus.refunded,
          status: BookingStatus.cancelled,
          refundAmount: 1000,
          cancelledAt: DateTime(2026, 10, 4, 9),
        ),
    ];
    expect(evaluateAdminOverviewAlert(now: now, bookings: busy), isNull);
  });

  test('지난주 결제 총액이 10만 원 이상이고 이번 주가 30% 이상 낮을 때만 알린다', () {
    AdminOverviewAlert? alert(int last, int current) {
      return evaluateAdminOverviewAlert(
        now: now,
        bookings: [
          booking(
            id: 'last',
            createdAt: DateTime(2026, 10, 13, 11),
            price: last,
            shopName: '제주 오렌지',
          ),
          booking(
            id: 'current',
            createdAt: DateTime(2026, 10, 20, 11),
            price: current,
            shopName: '제주 오렌지',
          ),
        ],
      );
    }

    expect(alert(100000, 70000)?.droppingShops, ['제주 오렌지']);
    expect(alert(100000, 70001), isNull);
    expect(alert(99999, 0), isNull);
  });

  test('부분 환불은 글자 배지로 구분하고, 가입은 변동에 남는다', () {
    final partial = booking(
      id: 'part',
      createdAt: now,
      price: 100000,
      paymentStatus: PaymentStatus.refunded,
      status: BookingStatus.cancelled,
      refundAmount: 30000,
      cancelledAt: now,
    );
    final full = booking(
      id: 'full',
      createdAt: now,
      price: 100000,
      paymentStatus: PaymentStatus.refunded,
      status: BookingStatus.cancelled,
      refundAmount: 100000,
      cancelledAt: now,
    );
    expect(liveBadgeFor(partial), AdminLiveBadge.partialRefund);
    expect(liveBadgeFor(full), AdminLiveBadge.cancelled);
    expect(
      liveBadgeFor(
        booking(id: 'paid', createdAt: now, status: BookingStatus.confirmed),
      ),
      AdminLiveBadge.paid,
    );

    final activity = buildAdminActivity(
      now: now,
      members: [
        MemberAccount(
          uid: 'm1',
          email: 'a@b.c',
          displayName: '김민수',
          grade: MemberGrade.silver,
          createdAt: DateTime(2026, 10, 20, 9),
        ),
      ],
      bookings: [partial],
      contracts: const [],
      applications: const [],
    );
    expect(activity.map((item) => item.kind), [
      AdminActivityKind.refund,
      AdminActivityKind.signup,
    ]);
    expect(activity.map((item) => item.label), ['제주 오렌지', '김민수']);
  });

  testWidgets('현황은 강사 인증 칸을 보여주고 상품 검증은 0건이면 숨긴다', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    var openedProposals = false;
    var openedApplications = false;

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AdminOverviewPane(
              onOpenInstructors: () {},
              onOpenContracts: () {},
              onOpenDiveStarReview: () {},
              onOpenBookings: () {},
              onOpenProducts: () {},
              onOpenProposals: () => openedProposals = true,
              onOpenApplications: () => openedApplications = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.text(l10n.adminOverviewQueueCertify), findsOneWidget);
    expect(find.text(l10n.adminOverviewQueueSign), findsOneWidget);
    expect(find.text(l10n.adminOverviewQueueDiveStar), findsOneWidget);
    expect(find.text(l10n.adminOverviewQueueProposal), findsOneWidget);
    expect(find.text(l10n.adminOverviewComingSoon), findsNothing);
    expect(find.text(l10n.adminOverviewActivityGap), findsOneWidget);
    expect(find.textContaining('파트너 제안은 준비 중'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('admin-overview-queue-proposal')),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('admin-overview-queue-proposal')));
    await tester.pump();
    expect(openedProposals, isTrue);
    expect(find.text(l10n.adminOverviewQueueApply), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('admin-overview-queue-apply')),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('admin-overview-queue-apply')));
    await tester.pump();
    expect(openedApplications, isTrue);
    expect(find.byKey(const Key('admin-overview-queue-products')), findsNothing);
    expect(find.text(l10n.adminVisitsTitle), findsNothing);
    expect(find.text('파트너 승격'), findsNothing);
    expect(find.byKey(const Key('admin-overview-basis')), findsOneWidget);

    tester.view.physicalSize = const Size(390, 2200);
    await tester.pump();
    expect(find.byKey(const Key('admin-overview-queue-certify')), findsOneWidget);
    expect(find.byKey(const Key('admin-overview-chart')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
