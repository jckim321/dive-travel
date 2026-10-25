import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/features/admin/analytics/admin_report_math.dart';
import 'package:dive_travel_app/features/admin/analytics/admin_sales_math.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_report_pdf.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_report_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  final now = DateTime(2026, 10, 21, 15);

  TourBooking booking({
    required String id,
    required DateTime createdAt,
    int price = 100000,
    String productId = 'p1',
    String optionName = '',
    PaymentStatus paymentStatus = PaymentStatus.captured,
    BookingStatus status = BookingStatus.confirmed,
    int refundAmount = 0,
  }) {
    return TourBooking(
      id: id,
      shopId: 'shop-a',
      shopName: '제주 오렌지',
      productId: productId,
      productName: '펀다이빙',
      price: price,
      createdAt: createdAt,
      optionName: optionName,
      paymentStatus: paymentStatus,
      status: status,
      refundAmount: refundAmount,
    );
  }

  const buckets = {
    AdminSalesBucket.tour,
    AdminSalesBucket.course,
    AdminSalesBucket.experience,
    AdminSalesBucket.sameBoat,
  };

  AdminReportDocument document({
    required List<TourBooking> bookings,
    Set<String> productKeys = const {},
  }) {
    final window = adminReportWindow(
      period: AdminReportPeriod.month,
      now: now,
    );
    return buildAdminReportDocument(
      bookings: bookings,
      window: window,
      compareWindow: adminReportCompareWindow(
        window: window,
        compare: AdminReportCompare.yearAgo,
      ),
      catalog: const [],
      buckets: buckets,
      shopIds: const {},
      productKeys: productKeys,
      periodLabel: '2026-10',
      showSummary: true,
      showTrend: true,
      showPartners: true,
      showProducts: true,
      showOptions: true,
      showCancels: true,
      showBasis: true,
      basisText: '계산 기준',
      fontLicense: 'Noto Sans KR는 SIL Open Font License(OFL)입니다.',
    );
  }

  test('보고서 요약 순매출은 판매현황과 같다', () {
    final bookings = [
      booking(id: 'kept', createdAt: DateTime(2026, 10, 3), price: 50000),
      booking(
        id: 'refunded',
        createdAt: DateTime(2026, 10, 4),
        price: 80000,
        paymentStatus: PaymentStatus.refunded,
        status: BookingStatus.cancelled,
        refundAmount: 30000,
      ),
    ];
    final window = adminReportWindow(period: AdminReportPeriod.month, now: now);
    final sales = buildAdminSalesSnapshot(
      bookings: bookings,
      window: window,
      compareWindow: adminReportCompareWindow(
        window: window,
        compare: AdminReportCompare.yearAgo,
      ),
      catalog: const [],
    );
    expect(document(bookings: bookings).snapshot.totals.net, sales.totals.net);
    expect(document(bookings: bookings).snapshot.totals.net, 100000);
  });

  test('상품을 하나만 고르면 옵션 이름 막대가 채워진다', () {
    final doc = document(
      bookings: [
        booking(
          id: 'gear',
          createdAt: DateTime(2026, 10, 5),
          optionName: '장비 · 픽업',
        ),
      ],
      productKeys: {'shop-a|p1'},
    );
    expect(doc.optionsApply, isTrue);
    expect(doc.options.map((row) => row.name), containsAll(['장비', '픽업']));
    expect(doc.topOption, '장비');
  });

  test('상품을 둘 고르면 옵션 집계를 적용하지 않는다', () {
    final doc = document(
      bookings: [
        booking(
          id: 'gear',
          createdAt: DateTime(2026, 10, 5),
          optionName: '장비',
        ),
      ],
      productKeys: {'shop-a|p1', 'shop-a|p2'},
    );
    expect(doc.optionsApply, isFalse);
    expect(doc.options, isEmpty);
  });

  test('비교 없음은 빈 구간이다', () {
    final window = adminReportWindow(period: AdminReportPeriod.month, now: now);
    final none = adminReportCompareWindow(
      window: window,
      compare: AdminReportCompare.none,
    );
    expect(none.contains(DateTime(2026, 10, 3)), isFalse);
    expect(none.start, none.end);
  });

  test('인쇄할 때만 폰트를 읽어 PDF 바이트를 만든다', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    final bytes = await buildAdminReportPdf(
      document(bookings: const []),
      l10n,
    );
    expect(bytes, isNotEmpty);
    expect(l10n.adminReportFontLicense, contains('OFL'));
  });

  testWidgets('보고서 만들기는 미리보기를 채우고 인쇄 전에는 폰트를 읽지 않는다', (
    tester,
  ) async {
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
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: AdminReportScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('admin-report-empty')), findsOneWidget);
    expect(find.byKey(const Key('admin-report-print')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('admin-report-make')));
    await tester.tap(find.byKey(const Key('admin-report-make')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('admin-report-net')), findsOneWidget);
    expect(find.byKey(const Key('admin-report-font-license')), findsOneWidget);
    expect(find.text(l10n.adminReportFontLicense), findsOneWidget);
    expect(find.text(l10n.adminStatsOptionsHint), findsOneWidget);
  });
}
