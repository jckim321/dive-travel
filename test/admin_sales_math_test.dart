import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/admin/analytics/admin_sales_math.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_sales_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  final now = DateTime(2026, 10, 21, 15);

  TourBooking booking({
    required String id,
    required DateTime createdAt,
    int price = 100000,
    PaymentStatus paymentStatus = PaymentStatus.captured,
    BookingStatus status = BookingStatus.confirmed,
    int refundAmount = 0,
    String shopId = 'shop-a',
    String shopName = '제주 오렌지',
    String productId = 'p1',
    String productName = '펀다이빙',
    bool fromFlag = false,
  }) {
    return TourBooking(
      id: id,
      shopId: shopId,
      shopName: shopName,
      productId: productId,
      productName: productName,
      price: price,
      createdAt: createdAt,
      paymentStatus: paymentStatus,
      status: status,
      refundAmount: refundAmount,
      fromFlag: fromFlag,
    );
  }

  AdminSalesSnapshot october(List<TourBooking> bookings, {List<AdminCatalogItem> catalog = const []}) {
    final window = adminSalesWindow(
      preset: AdminSalesPreset.thisMonth,
      now: now,
    );
    return buildAdminSalesSnapshot(
      bookings: bookings,
      window: window,
      compareWindow: adminSalesCompareWindow(
        window: window,
        compare: AdminSalesCompare.previous,
      ),
      catalog: catalog,
    );
  }

  test('한 달 순매출은 파트너 정산과 같고 환불을 뺀다', () {
    final bookings = [
      booking(
        id: 'paid-cancel',
        createdAt: DateTime(2026, 10, 2, 9),
        price: 100000,
        paymentStatus: PaymentStatus.refunded,
        status: BookingStatus.cancelled,
        refundAmount: 40000,
      ),
      booking(
        id: 'kept',
        createdAt: DateTime(2026, 10, 3, 9),
        price: 50000,
      ),
      booking(
        id: 'unpaid',
        createdAt: DateTime(2026, 10, 4, 9),
        price: 80000,
        paymentStatus: PaymentStatus.unpaid,
        status: BookingStatus.requested,
      ),
      booking(
        id: 'sep',
        createdAt: DateTime(2026, 9, 30, 23),
        price: 200000,
      ),
    ];
    final snap = october(bookings);
    expect(snap.totals.gross, 150000);
    expect(snap.totals.refund, 40000);
    expect(snap.totals.net, 110000);
    expect(
      snap.totals.net,
      partnerSettlementNet(bookings: bookings, year: 2026, month: 10),
    );
    expect(adminSalesNetForCalendarMonth(bookings: bookings, year: 2026, month: 9), 200000);
    expect(snap.totals.received, 3);
    expect(snap.totals.cancelCount, 1);
    expect(snap.totals.cancelRate, closeTo(1 / 3, 0.0001));
    expect(snap.partners.single.net, 110000);
    expect(snap.partners.single.gross, snap.totals.gross);
    final categoryNet = snap.categories.fold<int>(0, (sum, item) => sum + item.net);
    expect(categoryNet, snap.totals.net);
  });

  test('빈 기간은 0이고 전년 비교 창은 1년 전이다', () {
    final window = adminSalesWindow(preset: AdminSalesPreset.thisMonth, now: now);
    final year = adminSalesCompareWindow(
      window: window,
      compare: AdminSalesCompare.yearAgo,
    );
    expect(year.start, DateTime(2025, 10, 1));
    expect(year.end, DateTime(2025, 11, 1));
    final snap = october(const []);
    expect(snap.totals.received, 0);
    expect(snap.totals.net, 0);
    expect(snap.partners, isEmpty);
    expect(snap.compareTotals.net, 0);
  });

  test('직접 지정은 12개월을 넘기면 잘린다', () {
    final window = adminSalesWindow(
      preset: AdminSalesPreset.custom,
      now: now,
      customStart: DateTime(2025, 1, 15),
      customEnd: DateTime(2026, 6, 1),
    );
    expect(window.clamped, isTrue);
    expect(window.start, DateTime(2025, 1, 15));
    expect(window.end, DateTime(2026, 1, 15));
  });

  test('갈은배는 카테고리보다 먼저 묶고 체험 다이빙은 따로다', () {
    final catalog = [
      const AdminCatalogItem(
        shopId: 'shop-a',
        productId: 'fun',
        name: '펀다이빙',
        category: ProductCategory.funDive,
      ),
      const AdminCatalogItem(
        shopId: 'shop-a',
        productId: 'course',
        name: '오픈워터',
        category: ProductCategory.course,
      ),
    ];
    final snap = october(
      [
        booking(id: 'fun', createdAt: now, productId: 'fun', price: 30000),
        booking(
          id: 'flag',
          createdAt: now,
          productId: 'course',
          fromFlag: true,
          price: 20000,
        ),
      ],
      catalog: catalog,
    );
    final fun = snap.categories.firstWhere((item) => item.bucket == AdminSalesBucket.experience);
    final flag = snap.categories.firstWhere((item) => item.bucket == AdminSalesBucket.sameBoat);
    expect(fun.net, 30000);
    expect(flag.net, 20000);
  });

  testWidgets('판매현황은 KPI를 보여주고 파트너 행은 계약 보관함으로 연다', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.createBooking(
      uid: 'guest-1',
      shopId: 'bohol-hideout',
      shopName: '보홀 하이드아웃',
      productName: '펀다이빙',
      price: 120000,
      paymentStatus: PaymentStatus.captured,
      status: BookingStatus.confirmed,
    );
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    var opened = '';
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AdminSalesScreen(
              ownedShopId: 'bohol-hideout',
              onOpenContract: (id) => opened = id,
              onOpenDocuments: () {},
              onOpenPartners: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('admin-sales-kpi-gross')), findsOneWidget);
    expect(find.text(l10n.adminSalesNet), findsWidgets);
    expect(find.byKey(const Key('admin-sales-basis')), findsOneWidget);
    expect(find.text(l10n.adminContractsComingSoon), findsNothing);

    await tester.tap(find.byKey(const Key('admin-sales-row-bohol-hideout')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('admin-sales-open-contract')));
    await tester.pumpAndSettle();
    expect(opened, 'bohol-hideout');
    expect(find.text(l10n.adminSalesMine), findsOneWidget);
  });
}
