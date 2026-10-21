import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/app.dart';
import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/booking_quote.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  Future<AppLocalizations> loadKo() {
    return AppLocalizations.delegate.load(const Locale('ko'));
  }

  test('상품 카드는 출발일과 빈자리를 가진다', () {
    final dahab = DiveShopCatalog.byId('dahab-bluehole');
    expect(dahab, isNotNull);
    expect(dahab!.departure, isNotNull);
    expect(dahab.departure!.lastCall, isTrue);
    expect(dahab.departure!.emptySeats, 1);
    expect(dahab.departure!.windowLabel, '09.20 – 09.23');
  });

  test('기상 취소는 샵 예약을 weather_cancelled 로 바꾸고 전액 환불한다', () async {
    final repo = MemoryDiverRepository.forTest();
    final tour = DateTime(2026, 11, 1);
    await repo.createBooking(
      uid: 'test-user',
      shopId: AppConstants.defaultPartnerShopId,
      shopName: '보홀 오션 하이드아웃',
      productName: '2탱크 펀다이빙',
      price: 180000,
      tourDate: tour,
      status: BookingStatus.confirmed,
      paymentStatus: PaymentStatus.captured,
    );
    await repo.cancelBookingsForWeather(
      shopId: AppConstants.defaultPartnerShopId,
      tourDate: tour,
    );
    final bookings = await repo.watchBookings('test-user').first;
    expect(bookings.first.status, BookingStatus.weatherCancelled);
    expect(bookings.first.refundPercent, 100);
    expect(bookings.first.paymentStatus, PaymentStatus.refunded);
  });

  test('자리가 부족하면 결제 완료 예약을 만들지 않는다', () async {
    final repo = MemoryDiverRepository.forTest();
    const shopId = AppConstants.defaultPartnerShopId;
    const product = ShopProduct(
      id: 'seat-1',
      shopId: shopId,
      name: '2탱크',
      consumerPrice: 180000,
      professionalPrice: 126000,
      openEmptySeats: true,
      sameBoatStatus: SameBoatStatus.approved,
      capacity: 1,
      listingKind: ProductListingKind.diverPlanned,
      publishStatus: ProductPublishStatus.approved,
    );
    await repo.saveShopProduct(shopId: shopId, product: product);

    final blocked = await repo.createBooking(
      uid: 'test-user',
      shopId: shopId,
      shopName: '보홀',
      productName: product.name,
      price: 180000,
      productId: product.id,
      partySize: 2,
      optionId: 'pkg',
      listingKind: ProductListingKind.diverPlanned,
    );
    expect(blocked, isFalse);
    expect(await repo.watchBookings('test-user').first, isEmpty);

    final saved = await repo.createBooking(
      uid: 'test-user',
      shopId: shopId,
      shopName: '보홀',
      productName: product.name,
      price: 126000,
      productId: product.id,
      partySize: 1,
      optionId: 'pkg',
      seatOptionId: '',
      listingKind: ProductListingKind.diverPlanned,
      fromFlag: true,
      divers: 1,
      nondivers: 0,
      children: 0,
      infants: 0,
      quoteLines: const [
        BookingLine(label: '2탱크', amount: 126000),
      ],
    );
    expect(saved, isTrue);
    final bookings = await repo.watchBookings('test-user').first;
    expect(bookings, hasLength(1));
    expect(bookings.first.productId, product.id);
    expect(bookings.first.optionId, 'pkg');
    expect(bookings.first.listingKind, ProductListingKind.diverPlanned);
    expect(bookings.first.fromFlag, isTrue);
    expect(bookings.first.salesKind, 'flag');
    expect(bookings.first.partySize, 1);
    expect(bookings.first.divers, 1);
    expect(bookings.first.hasPartyDetail, isTrue);
    expect(bookings.first.quoteLines, hasLength(1));
    expect(bookings.first.quoteLines.first.amount, 126000);
    expect(bookings.first.status, BookingStatus.requested);
    expect(bookings.first.paymentStatus, PaymentStatus.unpaid);
    expect(bookings.first.isPaid, isFalse);
    expect(bookings.first.isActive, isTrue);
  });

  test('파트너 확정은 requested·unpaid 를 confirmed·captured 로 올린다', () async {
    final repo = MemoryDiverRepository.forTest();
    final tour = DateTime(2026, 12, 1);
    await repo.createBooking(
      uid: 'test-user',
      shopId: AppConstants.defaultPartnerShopId,
      shopName: '보홀',
      productName: '2탱크 · 나이트',
      price: 210000,
      tourDate: tour,
      quoteLines: const [
        BookingLine(label: '2탱크', amount: 180000),
        BookingLine(label: '나이트', amount: 30000),
      ],
    );
    final before = (await repo.watchBookings('test-user').first).first;
    expect(before.status, BookingStatus.requested);
    expect(before.paymentStatus, PaymentStatus.unpaid);

    final ok = await repo.confirmShopBooking(
      shopId: AppConstants.defaultPartnerShopId,
      bookingId: before.id,
    );
    expect(ok, isTrue);

    final after = (await repo.watchBookings('test-user').first).first;
    expect(after.status, BookingStatus.confirmed);
    expect(after.paymentStatus, PaymentStatus.captured);
    expect(after.isPaid, isTrue);
    expect(after.awaitsShopConfirm, isFalse);

    final again = await repo.confirmShopBooking(
      shopId: AppConstants.defaultPartnerShopId,
      bookingId: before.id,
    );
    expect(again, isFalse);
  });

  test('체크아웃 스냅샷은 상품명과 옵션명을 따로 마이페이지용으로 보관한다', () async {
    final repo = MemoryDiverRepository.forTest();
    final saved = await repo.createBooking(
      uid: 'test-user',
      shopId: AppConstants.defaultPartnerShopId,
      shopName: '보홀',
      productName: '2탱크 패키지',
      optionName: '나이트 다이빙',
      price: 210000,
      partySize: 2,
      divers: 2,
      quoteLines: const [
        BookingLine(label: '2탱크 패키지', amount: 180000),
        BookingLine(label: '나이트 다이빙', amount: 30000),
      ],
    );
    expect(saved, isTrue);
    final bookings = await repo.watchBookings('test-user').first;
    expect(bookings, hasLength(1));
    final booking = bookings.first;
    expect(booking.productLabel, '2탱크 패키지');
    expect(booking.optionLabel, '나이트 다이빙');
    expect(booking.displayTitle, '2탱크 패키지 · 나이트 다이빙');
    expect(booking.status, BookingStatus.requested);
    expect(booking.paymentStatus, PaymentStatus.unpaid);
    expect(booking.quoteLines, hasLength(2));
  });

  testWidgets('마이페이지에서 파트너 모드로 들어간다', (tester) async {
    await tester.pumpWidget(
      DiveTravelApp(
        firebaseReady: true,
        repository: MemoryDiverRepository.forTest(),
      ),
    );
    await tester.pump();
    await tester.pump();
    final l10n = await loadKo();

    await tester.tap(find.text(l10n.navProfile));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-profile-settings')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('profile-settings-scroll')),
      const Offset(0, -560),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('open-partner-mode')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('open-partner-mode')), findsOneWidget);
    await tester.tap(find.byKey(const Key('open-partner-mode')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.partnerTitle), findsWidgets);
    expect(find.text(l10n.partnerProductForm), findsOneWidget);
  });

  testWidgets('같은배 탭은 빈자리를 연 상품이 없으면 탐색으로 안내한다', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('ko');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);

    await tester.pumpWidget(
      DiveTravelApp(
        firebaseReady: true,
        repository: MemoryDiverRepository.forTest(),
      ),
    );
    await tester.pump();
    await tester.pump();
    final l10n = await loadKo();

    await tester.tap(find.text(l10n.navCommunity));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tide-board')), findsOneWidget);
    expect(find.text(l10n.communityDesignPreview), findsOneWidget);
  });
}
